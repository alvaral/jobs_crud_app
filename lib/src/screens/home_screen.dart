import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart' hide Job;
import 'package:jobs_crud_app/src/data/firestore_repository.dart';
import 'package:jobs_crud_app/src/data/job.dart';
import 'package:jobs_crud_app/src/routing/app_router.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs'), actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => context.goNamed(AppRoute.profile.name),
        )
      ]),
      body: const JobListView(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          final user = ref.read(firebaseAuthProvider).currentUser;
          final faker = Faker();
          final title = faker.job.title();
          final company = faker.company.name();
          ref.read(firestoreRepositoryProvider).addJob(
                user!.uid,
                title,
                company,
              );
        },
      ),
    );
  }
}

class JobListView extends ConsumerWidget {
  const JobListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreRepository = ref.watch(firestoreRepositoryProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    return FirestoreListView<Job>(
      query: firestoreRepository.jobsQuery(user!.uid),
      pageSize: 15,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(error.toString()),
      ),
      emptyBuilder: (context) => const Center(
        child: Text('No data'),
      ),
      itemBuilder: (BuildContext context, QueryDocumentSnapshot<Job> doc) {
        final job = doc.data();
        return Dismissible(
          key: Key(doc.id),
          background: const ColoredBox(color: Colors.red),
          direction: DismissDirection.endToStart,
          onDismissed: (directiion) {
            final user = ref.read(firebaseAuthProvider).currentUser;
            firestoreRepository.deleteJob(user!.uid, doc.id);
          },
          child: ListTile(
            title: Text(doc['title']),
            subtitle: Text(doc['company']),
            trailing: job.createdAt != null
                ? Text(job.createdAt.toString(),
                    style: Theme.of(context).textTheme.bodySmall)
                : null,
            onTap: () {
              final faker = Faker();
              final title = faker.job.title();
              final company = faker.company.name();
              ref.read(firestoreRepositoryProvider).updateJob(
                    user.uid,
                    doc.id,
                    title,
                    company,
                  );
            },
          ),
        );
      },
    );
  }
}
